# Author: Jire Lou
# Modified: 10/17/2022

import random
from math import sqrt

__INT_MAX__ = 2_147_483_647

class FixedLengthIntHasher:
    """A class that makes and stores an integer hash function with set length

        Attributes
        ----------
        hash_length: int
            Number of digits in hash output
        seed: int
            Seef for hash function modifier
        max_hashable_val: int
            Largest number that current has function can handle

        Methods
        -------
        setup(digit_count, seed=0):
            Creates new has function that fits input
        hash(num):
            Returns hash of provided number
            Note: Throws error if not setup 
    """
    _MIN_DIGIT_COUNT = 3
    _MAX_DIGIT_COUNT = 9


    def __init__(self, digit_count: int, seed: int = 0) -> None:
        """Constructs class attributes and creates hash function
        
        Args:
            digit_count (int): Length of hash output (3 - 9)
            seed (int, optional): Seeds random modifier in hasher. Defaults to 0.
        """
        self.setup(digit_count, seed)


    def setup(self, digit_count: int, seed: int = 0) -> None:
        """Constructs class attributes and creates hash function
        
        Args:
            digit_count (int): Length of hash output (3 - 9)
            seed (int, optional): Seeds random modifier in hasher. Defaults to 0.

        Rasises:
            FixedLengthIntHasher.InputError.BadDigitCount(): Digit count not within range 3-9
        """
        if digit_count < FixedLengthIntHasher._MIN_DIGIT_COUNT or digit_count > FixedLengthIntHasher._MAX_DIGIT_COUNT:
            raise FixedLengthIntHasher.InputError.BadDigitCount(digit_count)
        self.hash_length = digit_count

        #Create seed from digit count if no seed provided
        self.seed = seed if seed else random.Random(digit_count).randrange(__INT_MAX__)

        self._create_hasher() 


    def _largest_valid_prime_modulus(max_val: int) -> int:
        """Returns largest prime value, less than input, that is congruent to 3 (mod 4)

        Args:
            max_val (int): Max search range
        """
        def _first_prime_under(starting_num: int):
            def _is_prime(num: int): 
                return all(num % i for i in range(2, int(sqrt(num)) + 1))

            for i in range(starting_num, 2, -1): 
                if _is_prime(i): 
                    return i
            return -1 

        prime = _first_prime_under(max_val)
        #While not p ≡ 3 (mod 4)
        while not prime % 4 == 3:
            prime = _first_prime_under(prime - 1)

        return prime


    def _create_hasher(self) -> None:
        """Creates hash function and attaches it to class instance

        Raises:
            FixedLengthIntHasher.InputError.BadIndex: Input outside of valid range
            FixedLengthIntHasher.InternalError.BadIndex: Unexpected - Result of hash doesn't fit requirements
        """
        srandom = random.Random(self.hash_length + self.seed)

        #Set to 100... & 999...
        MIN_VAL = int(f"1{''.join(list(['0'] * (self.hash_length - 1)))}")
        THEORETICAL_MAX = int(''.join(list(['9'] * self.hash_length)))
        
        PRIME_MODULUS = FixedLengthIntHasher._largest_valid_prime_modulus(THEORETICAL_MAX - MIN_VAL)
        HALF_PRIME_MODULUS = PRIME_MODULUS / 2

        PRACTICAL_MAX = PRIME_MODULUS
        
        RAND_MODIFIER = srandom.randrange(MIN_VAL, int(0.75 * PRIME_MODULUS))
        
        def integer_hasher(num):
            if num < 0 or num > PRACTICAL_MAX: raise FixedLengthIntHasher.InputError.BadIndex(num, 0, PRACTICAL_MAX)

            modified_val = RAND_MODIFIER + num
            #Set to difference with Mod or 2Mod if negative
            modified_val = (1 + (modified_val > PRIME_MODULUS)) * PRIME_MODULUS - modified_val

            #Get res mod with func X^2 % p
            residue_modulo = (modified_val ** 2) % PRIME_MODULUS
            #Invert res mod when larger start val
            residue_modulo = residue_modulo if (modified_val <= HALF_PRIME_MODULUS) else PRIME_MODULUS - residue_modulo

            if residue_modulo < 0 or residue_modulo > PRIME_MODULUS: raise FixedLengthIntHasher.InternalError.BadResult()

            return MIN_VAL + residue_modulo
        
        self.hash = integer_hasher
        self.max_hashable_val = PRACTICAL_MAX
    

    def hash(self, num: int)-> int:
        """Converts number to fixed length hash

        Args:
            num (int): Number to hash

        Raises:
            FixedLengthIntHasher.InputError.EmptyHashFunc: Hasher hasn't been setup
        """
        raise FixedLengthIntHasher.InputError.EmptyHashFunc()


    class InputError:
        """Hash function usage error"""
        class BadDigitCount(ValueError):
            def __init__(self, val: int):
                is_big = val > FixedLengthIntHasher._MAX_DIGIT_COUNT
                self.msg = f'Provided value ({val}) is {"more" if is_big else "less"} than boundry {FixedLengthIntHasher._MAX_DIGIT_COUNT if is_big else FixedLengthIntHasher._MIN_DIGIT_COUNT}'
                super().__init__(self.msg)

        class BadIndex(ValueError):
            def __init__(self, val: int, min_val: int, max_val: int):
                is_upper_breach = val > max_val
                self.msg = f'Provided value ({val}) is {"more" if is_upper_breach else "less"} than boundry {max_val if is_upper_breach else min_val}'
                super().__init__(self.msg)

        class EmptyHashFunc(Exception):
            def __init__(self):
                self.msg = f'Hash function has not been setup with constructor or setup()'
                super().__init__(self.msg)

    class InternalError:
        """Hash function proccess error"""
        class BadResult(Exception):
            def __init__(self):
                self.msg = f'Internal Error: Final value is outside of expected bounds'
                super().__init__(self.msg)


if __name__ == '__main__':
    myHasher = FixedLengthIntHasher(6)

    #Test uniqueness
    hash_dict = {}
    for num in range(myHasher.max_hashable_val):
        hashed = myHasher.hash(num)
        if hashed in hash_dict:
            raise Exception(f'Test Failed {hash_dict[hashed]}')
        hash_dict[hashed] = num

        print(f'{(num/myHasher.max_hashable_val):.3%}:\tNUM: {num},\tHASHED: {myHasher.hash(num)}')
    
    #Test speed
    import time
    hash_speeds = []
    for i in range(500):
        rand_num = random.randrange(myHasher.max_hashable_val)
        start_time = time.perf_counter_ns()
        myHasher.hash(rand_num)
        end_time = time.perf_counter_ns()
        hash_speeds.append((end_time - start_time) / 1_000_000)
    avg_hash_speed = sum(hash_speeds) / len(hash_speeds)
    
    #Output Results
    print(
f"""
          Test Success
--------------------------------
Hash Speed: {avg_hash_speed:.4f}ms

Hash Length: {myHasher.hash_length}
Hash Seed: {myHasher.seed}
Max Hashable: {myHasher.max_hashable_val}
"""
    )
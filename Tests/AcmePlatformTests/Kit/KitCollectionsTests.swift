import AcmePlatform
import Foundation
import Testing

@Suite struct KitCollectionsTests {
    @Test func chunksIntoBatches() throws {
        let items: [Int] = [1, 2, 3, 4, 5, 6, 7]
        let chunks = Kit.Collections.chunk(items, size: 3)
        #expect(chunks.count == 3)
        #expect(chunks[2].count == 1)
    }

    @Test func filtersAndCounts() throws {
        let items: [Int] = [4, 9, 15, 16, 23, 42]
        let even = Kit.Collections.filter(items, keep: { (n: Int) -> Bool in return n % 2 == 0 })
        #expect(even.count == 3)
        let counts = Kit.Collections.countBy(items, key: { (n: Int) -> String in
            if n > 10 {
                return "big"
            }
            return "small"
        })
        #expect(counts["big", default: 0] == 4)
    }

    @Test func dropsRepeatedStrings() throws {
        #expect(Kit.Collections.uniqueStrings(["a", "b", "a"]).count == 2)
    }
}

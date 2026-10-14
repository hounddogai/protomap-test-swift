@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeClaimStore = Labs.newMemoryReferenceRangeClaimStore()
        let item = Labs.newReferenceRangeClaim("code-456", label: "label-997")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

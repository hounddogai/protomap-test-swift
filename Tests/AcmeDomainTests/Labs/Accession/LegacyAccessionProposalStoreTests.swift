@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLegacyAccessionProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LegacyAccessionProposalStore = Labs.newMemoryLegacyAccessionProposalStore()
        let item = Labs.newLegacyAccessionProposal("code-626", name: "name-323")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

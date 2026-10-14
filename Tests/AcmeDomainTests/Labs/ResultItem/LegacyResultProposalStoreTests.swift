@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLegacyResultProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LegacyResultProposalStore = Labs.newMemoryLegacyResultProposalStore()
        let item = Labs.newLegacyResultProposal("code-508", title: "title-138")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

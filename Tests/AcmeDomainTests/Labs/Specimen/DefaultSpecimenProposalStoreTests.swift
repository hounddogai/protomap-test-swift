@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryDefaultSpecimenProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.DefaultSpecimenProposalStore = Labs.newMemoryDefaultSpecimenProposalStore()
        let item = Labs.newDefaultSpecimenProposal("code-893", name: "name-89")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryDefaultCourierProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.DefaultCourierProposalStore = Labs.newMemoryDefaultCourierProposalStore()
        let item = Labs.newDefaultCourierProposal("code-758", name: "name-27")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

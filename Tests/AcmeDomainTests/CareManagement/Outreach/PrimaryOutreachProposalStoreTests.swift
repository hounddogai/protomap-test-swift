@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPrimaryOutreachProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PrimaryOutreachProposalStore = CareManagement.newMemoryPrimaryOutreachProposalStore()
        let item = CareManagement.newPrimaryOutreachProposal("code-106", name: "name-296")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

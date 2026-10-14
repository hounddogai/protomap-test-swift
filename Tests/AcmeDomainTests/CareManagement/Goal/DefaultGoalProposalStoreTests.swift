@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryDefaultGoalProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.DefaultGoalProposalStore = CareManagement.newMemoryDefaultGoalProposalStore()
        let item = CareManagement.newDefaultGoalProposal("code-773", name: "name-810")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

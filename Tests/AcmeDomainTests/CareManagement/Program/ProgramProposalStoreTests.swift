@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramProposalStore = CareManagement.newMemoryProgramProposalStore()
        let item = CareManagement.newProgramProposal("code-717", label: "label-626")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

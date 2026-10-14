@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimeProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimeProposalStore = Staffing.newMemoryOvertimeProposalStore()
        let item = Staffing.newOvertimeProposal("code-964", name: "name-244")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

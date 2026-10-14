@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolProposalStore = Staffing.newMemoryFloatPoolProposalStore()
        let item = Staffing.newFloatPoolProposal("code-119", title: "title-735")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

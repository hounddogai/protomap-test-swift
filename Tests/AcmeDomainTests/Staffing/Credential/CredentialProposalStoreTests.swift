@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialProposalStore = Staffing.newMemoryCredentialProposalStore()
        let item = Staffing.newCredentialProposal("code-663", title: "title-751")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

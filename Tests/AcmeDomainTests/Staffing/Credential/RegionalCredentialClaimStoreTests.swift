@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRegionalCredentialClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RegionalCredentialClaimStore = Staffing.newMemoryRegionalCredentialClaimStore()
        let item = Staffing.newRegionalCredentialClaim("code-158", label: "label-566")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

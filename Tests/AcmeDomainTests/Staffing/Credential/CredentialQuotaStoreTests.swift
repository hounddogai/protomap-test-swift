@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialQuotaStore = Staffing.newMemoryCredentialQuotaStore()
        let item = Staffing.newCredentialQuota("code-284", title: "title-22")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

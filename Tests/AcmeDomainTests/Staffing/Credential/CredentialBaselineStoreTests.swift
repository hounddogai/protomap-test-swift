@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialBaselineStore = Staffing.newMemoryCredentialBaselineStore()
        let item = Staffing.newCredentialBaseline("code-263", title: "title-472")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

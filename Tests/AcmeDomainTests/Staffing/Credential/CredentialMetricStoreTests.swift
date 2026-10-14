@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialMetricStore = Staffing.newMemoryCredentialMetricStore()
        let item = Staffing.newCredentialMetric("code-142", name: "name-464")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

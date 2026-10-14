@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialForecastStore = Staffing.newMemoryCredentialForecastStore()
        let item = Staffing.newCredentialForecast("code-173", title: "title-67")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

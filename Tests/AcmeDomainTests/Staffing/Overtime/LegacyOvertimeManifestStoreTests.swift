@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryLegacyOvertimeManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.LegacyOvertimeManifestStore = Staffing.newMemoryLegacyOvertimeManifestStore()
        let item = Staffing.newLegacyOvertimeManifest("code-876", name: "name-87")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

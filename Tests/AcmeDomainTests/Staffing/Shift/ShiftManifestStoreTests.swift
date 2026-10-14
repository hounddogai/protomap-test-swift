@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftManifestStore = Staffing.newMemoryShiftManifestStore()
        let item = Staffing.newShiftManifest("code-44", label: "label-970")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

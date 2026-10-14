@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryStrictShiftBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.StrictShiftBundleStore = Staffing.newMemoryStrictShiftBundleStore()
        let item = Staffing.newStrictShiftBundle("code-541", name: "name-600")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

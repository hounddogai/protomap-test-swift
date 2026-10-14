@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryGlobalShiftProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.GlobalShiftProfileStore = Staffing.newMemoryGlobalShiftProfileStore()
        let item = Staffing.newGlobalShiftProfile("code-100", name: "name-635")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

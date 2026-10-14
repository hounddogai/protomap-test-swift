@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryDefaultShiftProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.DefaultShiftProfileStore = Staffing.newMemoryDefaultShiftProfileStore()
        let item = Staffing.newDefaultShiftProfile("code-544", label: "label-886")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

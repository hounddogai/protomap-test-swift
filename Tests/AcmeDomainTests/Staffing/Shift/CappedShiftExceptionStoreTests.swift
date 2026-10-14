@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCappedShiftExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CappedShiftExceptionStore = Staffing.newMemoryCappedShiftExceptionStore()
        let item = Staffing.newCappedShiftException("code-335", name: "name-74")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

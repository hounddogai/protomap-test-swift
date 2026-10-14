@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryGlobalShiftTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.GlobalShiftTemplateStore = Staffing.newMemoryGlobalShiftTemplateStore()
        let item = Staffing.newGlobalShiftTemplate("code-606", label: "label-987")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

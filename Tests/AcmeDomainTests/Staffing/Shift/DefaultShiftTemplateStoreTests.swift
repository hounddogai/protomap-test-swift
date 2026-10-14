@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryDefaultShiftTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.DefaultShiftTemplateStore = Staffing.newMemoryDefaultShiftTemplateStore()
        let item = Staffing.newDefaultShiftTemplate("code-523", label: "label-190")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

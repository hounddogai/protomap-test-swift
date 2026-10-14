@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolBaselineStore = Staffing.newMemoryFloatPoolBaselineStore()
        let item = Staffing.newFloatPoolBaseline("code-74", label: "label-354")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

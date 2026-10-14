@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryManualOvertimeVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ManualOvertimeVarianceStore = Staffing.newMemoryManualOvertimeVarianceStore()
        let item = Staffing.newManualOvertimeVariance("code-77", label: "label-542")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCappedAssessmentScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CappedAssessmentScheduleStore = CareManagement.newMemoryCappedAssessmentScheduleStore()
        let item = CareManagement.newCappedAssessmentSchedule("code-623", label: "label-883")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

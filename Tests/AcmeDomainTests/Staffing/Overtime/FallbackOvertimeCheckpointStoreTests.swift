@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFallbackOvertimeCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FallbackOvertimeCheckpointStore = Staffing.newMemoryFallbackOvertimeCheckpointStore()
        let item = Staffing.newFallbackOvertimeCheckpoint("code-197", title: "title-175")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

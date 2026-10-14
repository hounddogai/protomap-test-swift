@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskReservationStore = ClinicalOps.newMemoryTaskReservationStore()
        let item = ClinicalOps.newTaskReservation("code-229", title: "title-880")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

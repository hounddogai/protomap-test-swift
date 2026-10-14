@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertReservationStore = ClinicalOps.newMemoryAlertReservationStore()
        let item = ClinicalOps.newAlertReservation("code-506", title: "title-679")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

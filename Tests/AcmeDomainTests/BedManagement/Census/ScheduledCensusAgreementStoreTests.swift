@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryScheduledCensusAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ScheduledCensusAgreementStore = BedManagement.newMemoryScheduledCensusAgreementStore()
        let item = BedManagement.newScheduledCensusAgreement("code-895", name: "name-920")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

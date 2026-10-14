@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanAgreementStore = Staffing.newMemoryAcuityPlanAgreementStore()
        let item = Staffing.newAcuityPlanAgreement("code-748", label: "label-564")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

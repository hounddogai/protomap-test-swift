@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationAssignmentStore = RevenueCycle.newMemoryAuthorizationAssignmentStore()
        let item = RevenueCycle.newAuthorizationAssignment("code-832", name: "name-617")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}

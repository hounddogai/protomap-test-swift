import AcmePlatform
import Foundation

extension Staffing {
    /// Moves credential metrics through their life cycle and keeps a journal of what it did.
    final class CredentialMetricManager {
        var store: any CredentialMetricStore
        var validator: CredentialMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CredentialMetricStore, validator: CredentialMetricValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CredentialMetricStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("credential metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CredentialMetricStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newCredentialMetricManager(_ store: any CredentialMetricStore, clock: any Kit.Clocks.Clock) -> CredentialMetricManager {
        return CredentialMetricManager(
            store: store,
            validator: defaultCredentialMetricValidator(),
            clock: clock,
            journal: []
        )
    }
}

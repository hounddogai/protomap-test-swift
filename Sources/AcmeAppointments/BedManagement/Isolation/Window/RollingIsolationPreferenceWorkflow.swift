import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves rolling isolation preferences through their life cycle and keeps a journal of what it did.
    final class RollingIsolationPreferenceCoordinator {
        var store: any RollingIsolationPreferenceStore
        var validator: RollingIsolationPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingIsolationPreferenceStore, validator: RollingIsolationPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling isolation preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingIsolationPreferenceStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling isolation preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingIsolationPreferenceStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRollingIsolationPreferenceCoordinator(_ store: any RollingIsolationPreferenceStore, clock: any Kit.Clocks.Clock) -> RollingIsolationPreferenceCoordinator {
        return RollingIsolationPreferenceCoordinator(
            store: store,
            validator: defaultRollingIsolationPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}

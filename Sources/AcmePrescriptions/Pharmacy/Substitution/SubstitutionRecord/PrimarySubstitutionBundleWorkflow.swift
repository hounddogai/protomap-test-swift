import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves primary substitution bundles through their life cycle and keeps a journal of what it did.
    final class PrimarySubstitutionBundleCoordinator {
        var store: any PrimarySubstitutionBundleStore
        var validator: PrimarySubstitutionBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimarySubstitutionBundleStore, validator: PrimarySubstitutionBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("primary substitution bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimarySubstitutionBundleStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary substitution bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimarySubstitutionBundleStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newPrimarySubstitutionBundleCoordinator(_ store: any PrimarySubstitutionBundleStore, clock: any Kit.Clocks.Clock) -> PrimarySubstitutionBundleCoordinator {
        return PrimarySubstitutionBundleCoordinator(
            store: store,
            validator: defaultPrimarySubstitutionBundleValidator(),
            clock: clock,
            journal: []
        )
    }
}

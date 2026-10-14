import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves adaptive substitution bundles through their life cycle and keeps a journal of what it did.
    final class AdaptiveSubstitutionBundleManager {
        var store: any AdaptiveSubstitutionBundleStore
        var validator: AdaptiveSubstitutionBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveSubstitutionBundleStore, validator: AdaptiveSubstitutionBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("adaptive substitution bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveSubstitutionBundleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive substitution bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveSubstitutionBundleStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newAdaptiveSubstitutionBundleManager(_ store: any AdaptiveSubstitutionBundleStore, clock: any Kit.Clocks.Clock) -> AdaptiveSubstitutionBundleManager {
        return AdaptiveSubstitutionBundleManager(
            store: store,
            validator: defaultAdaptiveSubstitutionBundleValidator(),
            clock: clock,
            journal: []
        )
    }
}

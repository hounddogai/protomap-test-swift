import AcmePlatform
import Foundation

extension Labs {
    /// Moves adaptive accession bundles through their life cycle and keeps a journal of what it did.
    final class AdaptiveAccessionBundleWorkflow {
        var store: any AdaptiveAccessionBundleStore
        var validator: AdaptiveAccessionBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveAccessionBundleStore, validator: AdaptiveAccessionBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("adaptive accession bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveAccessionBundleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive accession bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveAccessionBundleStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newAdaptiveAccessionBundleWorkflow(_ store: any AdaptiveAccessionBundleStore, clock: any Kit.Clocks.Clock) -> AdaptiveAccessionBundleWorkflow {
        return AdaptiveAccessionBundleWorkflow(
            store: store,
            validator: defaultAdaptiveAccessionBundleValidator(),
            clock: clock,
            journal: []
        )
    }
}

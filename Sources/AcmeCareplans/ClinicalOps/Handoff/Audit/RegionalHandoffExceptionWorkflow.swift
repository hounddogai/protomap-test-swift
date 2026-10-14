import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves regional handoff exceptions through their life cycle and keeps a journal of what it did.
    final class RegionalHandoffExceptionCoordinator {
        var store: any RegionalHandoffExceptionStore
        var validator: RegionalHandoffExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalHandoffExceptionStore, validator: RegionalHandoffExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional handoff exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalHandoffExceptionStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional handoff exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalHandoffExceptionStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newRegionalHandoffExceptionCoordinator(_ store: any RegionalHandoffExceptionStore, clock: any Kit.Clocks.Clock) -> RegionalHandoffExceptionCoordinator {
        return RegionalHandoffExceptionCoordinator(
            store: store,
            validator: defaultRegionalHandoffExceptionValidator(),
            clock: clock,
            journal: []
        )
    }
}

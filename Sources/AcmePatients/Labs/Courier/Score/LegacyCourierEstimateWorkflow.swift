import AcmePlatform
import Foundation

extension Labs {
    /// Moves legacy courier estimates through their life cycle and keeps a journal of what it did.
    final class LegacyCourierEstimateCoordinator {
        var store: any LegacyCourierEstimateStore
        var validator: LegacyCourierEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyCourierEstimateStore, validator: LegacyCourierEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("legacy courier estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyCourierEstimateStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy courier estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyCourierEstimateStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newLegacyCourierEstimateCoordinator(_ store: any LegacyCourierEstimateStore, clock: any Kit.Clocks.Clock) -> LegacyCourierEstimateCoordinator {
        return LegacyCourierEstimateCoordinator(
            store: store,
            validator: defaultLegacyCourierEstimateValidator(),
            clock: clock,
            journal: []
        )
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves primary care gap groups through their life cycle and keeps a journal of what it did.
    final class PrimaryCareGapGroupWorkflow {
        var store: any PrimaryCareGapGroupStore
        var validator: PrimaryCareGapGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryCareGapGroupEngine

        init(store: any PrimaryCareGapGroupStore, validator: PrimaryCareGapGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryCareGapGroupEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary care gap group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryCareGapGroupStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary care gap group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryCareGapGroupStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary care gap group \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newPrimaryCareGapGroupWorkflow(_ store: any PrimaryCareGapGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryCareGapGroupWorkflow {
        return PrimaryCareGapGroupWorkflow(
            store: store,
            validator: defaultPrimaryCareGapGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryCareGapGroupEngine(flags)
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves default discharge plan windows through their life cycle and keeps a journal of what it did.
    final class DefaultDischargePlanWindowService {
        var store: any DefaultDischargePlanWindowStore
        var validator: DefaultDischargePlanWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultDischargePlanWindowEngine

        init(store: any DefaultDischargePlanWindowStore, validator: DefaultDischargePlanWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultDischargePlanWindowEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default discharge plan window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultDischargePlanWindowStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default discharge plan window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultDischargePlanWindowStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default discharge plan window \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newDefaultDischargePlanWindowService(_ store: any DefaultDischargePlanWindowStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultDischargePlanWindowService {
        return DefaultDischargePlanWindowService(
            store: store,
            validator: defaultDefaultDischargePlanWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultDischargePlanWindowEngine(flags)
        )
    }
}

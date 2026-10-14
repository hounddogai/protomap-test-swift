import AcmePlatform
import Foundation

extension Staffing {
    /// Moves adaptive float pool cycles through their life cycle and keeps a journal of what it did.
    final class AdaptiveFloatPoolCycleDesk {
        var store: any AdaptiveFloatPoolCycleStore
        var validator: AdaptiveFloatPoolCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveFloatPoolCycleEngine

        init(store: any AdaptiveFloatPoolCycleStore, validator: AdaptiveFloatPoolCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveFloatPoolCycleEngine) {
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
                throw Kit.Failure("adaptive float pool cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveFloatPoolCycleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive float pool cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveFloatPoolCycleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive float pool cycle \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newAdaptiveFloatPoolCycleDesk(_ store: any AdaptiveFloatPoolCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveFloatPoolCycleDesk {
        return AdaptiveFloatPoolCycleDesk(
            store: store,
            validator: defaultAdaptiveFloatPoolCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveFloatPoolCycleEngine(flags)
        )
    }
}

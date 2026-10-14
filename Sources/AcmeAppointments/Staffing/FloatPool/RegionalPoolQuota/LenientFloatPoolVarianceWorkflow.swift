import AcmePlatform
import Foundation

extension Staffing {
    /// Moves lenient float pool variances through their life cycle and keeps a journal of what it did.
    final class LenientFloatPoolVarianceService {
        var store: any LenientFloatPoolVarianceStore
        var validator: LenientFloatPoolVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientFloatPoolVarianceEngine

        init(store: any LenientFloatPoolVarianceStore, validator: LenientFloatPoolVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientFloatPoolVarianceEngine) {
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
                throw Kit.Failure("lenient float pool variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientFloatPoolVarianceStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient float pool variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientFloatPoolVarianceStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient float pool variance \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newLenientFloatPoolVarianceService(_ store: any LenientFloatPoolVarianceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientFloatPoolVarianceService {
        return LenientFloatPoolVarianceService(
            store: store,
            validator: defaultLenientFloatPoolVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientFloatPoolVarianceEngine(flags)
        )
    }
}

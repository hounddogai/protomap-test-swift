import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool estimates through their life cycle and keeps a journal of what it did.
    final class FloatPoolEstimateManager {
        var store: any FloatPoolEstimateStore
        var validator: FloatPoolEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FloatPoolEstimateEngine

        init(store: any FloatPoolEstimateStore, validator: FloatPoolEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FloatPoolEstimateEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolEstimateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolEstimateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool estimate \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newFloatPoolEstimateManager(_ store: any FloatPoolEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FloatPoolEstimateManager {
        return FloatPoolEstimateManager(
            store: store,
            validator: defaultFloatPoolEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultFloatPoolEstimateEngine(flags)
        )
    }
}

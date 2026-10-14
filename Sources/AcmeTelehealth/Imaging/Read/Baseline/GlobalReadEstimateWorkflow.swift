import AcmePlatform
import Foundation

extension Imaging {
    /// Moves global read estimates through their life cycle and keeps a journal of what it did.
    final class GlobalReadEstimateService {
        var store: any GlobalReadEstimateStore
        var validator: GlobalReadEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalReadEstimateEngine

        init(store: any GlobalReadEstimateStore, validator: GlobalReadEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalReadEstimateEngine) {
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
                throw Kit.Failure("global read estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalReadEstimateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global read estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalReadEstimateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global read estimate \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newGlobalReadEstimateService(_ store: any GlobalReadEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalReadEstimateService {
        return GlobalReadEstimateService(
            store: store,
            validator: defaultGlobalReadEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalReadEstimateEngine(flags)
        )
    }
}

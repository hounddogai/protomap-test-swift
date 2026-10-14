import AcmePlatform
import Foundation

extension Labs {
    /// Moves courier estimates through their life cycle and keeps a journal of what it did.
    final class CourierEstimateService {
        var store: any CourierEstimateStore
        var validator: CourierEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CourierEstimateEngine

        init(store: any CourierEstimateStore, validator: CourierEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CourierEstimateEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CourierEstimateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CourierEstimateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier estimate \(code) not found")
            }
            let result = engine.run(item)
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

    static func newCourierEstimateService(_ store: any CourierEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CourierEstimateService {
        return CourierEstimateService(
            store: store,
            validator: defaultCourierEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultCourierEstimateEngine(flags)
        )
    }
}

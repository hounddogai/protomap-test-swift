import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves census metrics through their life cycle and keeps a journal of what it did.
    final class CensusMetricService {
        var store: any CensusMetricStore
        var validator: CensusMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CensusMetricEngine

        init(store: any CensusMetricStore, validator: CensusMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CensusMetricEngine) {
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
                throw Kit.Failure("census metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CensusMetricStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("census metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CensusMetricStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("census metric \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newCensusMetricService(_ store: any CensusMetricStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CensusMetricService {
        return CensusMetricService(
            store: store,
            validator: defaultCensusMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultCensusMetricEngine(flags)
        )
    }
}

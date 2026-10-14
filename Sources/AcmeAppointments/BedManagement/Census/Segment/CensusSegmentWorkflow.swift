import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves census segments through their life cycle and keeps a journal of what it did.
    final class CensusSegmentManager {
        var store: any CensusSegmentStore
        var validator: CensusSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CensusSegmentEngine

        init(store: any CensusSegmentStore, validator: CensusSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CensusSegmentEngine) {
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
                throw Kit.Failure("census segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CensusSegmentStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("census segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CensusSegmentStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("census segment \(code) not found")
            }
            let result = engine.price(item)
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

    static func newCensusSegmentManager(_ store: any CensusSegmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CensusSegmentManager {
        return CensusSegmentManager(
            store: store,
            validator: defaultCensusSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultCensusSegmentEngine(flags)
        )
    }
}

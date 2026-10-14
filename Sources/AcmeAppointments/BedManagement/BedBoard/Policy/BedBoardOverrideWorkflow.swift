import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves bed board overrides through their life cycle and keeps a journal of what it did.
    final class BedBoardOverrideService {
        var store: any BedBoardOverrideStore
        var validator: BedBoardOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BedBoardOverrideEngine

        init(store: any BedBoardOverrideStore, validator: BedBoardOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BedBoardOverrideEngine) {
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
                throw Kit.Failure("bed board override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BedBoardOverrideStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BedBoardOverrideStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board override \(code) not found")
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

    static func newBedBoardOverrideService(_ store: any BedBoardOverrideStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> BedBoardOverrideService {
        return BedBoardOverrideService(
            store: store,
            validator: defaultBedBoardOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultBedBoardOverrideEngine(flags)
        )
    }
}

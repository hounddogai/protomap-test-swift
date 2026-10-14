import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves legacy program notices through their life cycle and keeps a journal of what it did.
    final class LegacyProgramNoticeDesk {
        var store: any LegacyProgramNoticeStore
        var validator: LegacyProgramNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyProgramNoticeEngine

        init(store: any LegacyProgramNoticeStore, validator: LegacyProgramNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyProgramNoticeEngine) {
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
                throw Kit.Failure("legacy program notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyProgramNoticeStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy program notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyProgramNoticeStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy program notice \(code) not found")
            }
            let result = engine.run(item)
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

    static func newLegacyProgramNoticeDesk(_ store: any LegacyProgramNoticeStore, clock: any Kit.Clocks.Clock) -> LegacyProgramNoticeDesk {
        return LegacyProgramNoticeDesk(
            store: store,
            validator: defaultLegacyProgramNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyProgramNoticeEngine()
        )
    }
}

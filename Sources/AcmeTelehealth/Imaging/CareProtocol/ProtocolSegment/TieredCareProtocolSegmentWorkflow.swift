import AcmePlatform
import Foundation

extension Imaging {
    /// Moves tiered care protocol segments through their life cycle and keeps a journal of what it did.
    final class TieredCareProtocolSegmentManager {
        var store: any TieredCareProtocolSegmentStore
        var validator: TieredCareProtocolSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredCareProtocolSegmentEngine

        init(store: any TieredCareProtocolSegmentStore, validator: TieredCareProtocolSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredCareProtocolSegmentEngine) {
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
                throw Kit.Failure("tiered care protocol segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredCareProtocolSegmentStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered care protocol segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredCareProtocolSegmentStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered care protocol segment \(code) not found")
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

    static func newTieredCareProtocolSegmentManager(_ store: any TieredCareProtocolSegmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredCareProtocolSegmentManager {
        return TieredCareProtocolSegmentManager(
            store: store,
            validator: defaultTieredCareProtocolSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredCareProtocolSegmentEngine(flags)
        )
    }
}
